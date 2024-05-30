source /usr/share/fish/completions/git.fish

function __fish_git_files
    # A function to show various kinds of files git knows about,
    # by parsing `git status --porcelain`.
    #
    # This accepts arguments to denote the kind of files:
    # - added: Staged added files (unstaged adds are untracked)
    # - copied
    # - deleted
    # - deleted-staged
    # - ignored
    # - modified: Files that have been modified (but aren't staged)
    # - modified-staged: Staged modified files
    # - renamed
    # - untracked
    # and as a convenience "all-staged"
    # to get _all_ kinds of staged files.

    # Save the repo root to remove it from the path later.
    # set -l root (__fish_git rev-parse --show-toplevel --is-bare-repository 2>/dev/null)
    set -l root (__fish_git rev-parse --show-toplevel 2>/dev/null)
    or return
    
    # Thanks https://github.com/fish-shell/fish-shell/issues/8592#issuecomment-1001860113
    set -a root (__fish_git config --get core.bare 2>/dev/null)
    or return

    # Respect dotfiles repo
    set -l cmdline (commandline -opc)
    set -l dotfiles $(test "$cmdline[2]" = "--git-dir=\$HOME/.dotfiles/" && echo true || echo false)
    # Bare repository and not dotfiles
    if test "$root[2]" = true -a "$dotfiles" = false
        __fish_complete_path
        return
    end
    if test "$root[2]" = true -a "$dotfiles" = true -a "$cmdline[4]" = add
        __fish_complete_path
        return
    end
    set -e root[2]

    # Cache the translated descriptions so we don't have to get it
    # once per file.
    contains -- all-staged $argv; and set -l all_staged
    contains -- unmerged $argv; and set -l unmerged
    and set -l unmerged_desc "Unmerged File"
    contains -- added $argv; or set -ql all_staged; and set -l added
    and set -l added_desc "Added file"
    contains -- modified $argv; and set -l modified
    and set -l modified_desc "Modified file"
    contains -- untracked $argv; and set -l untracked
    and set -l untracked_desc "Untracked file"
    contains -- modified-staged $argv; or set -ql all_staged; and set -l modified_staged
    and set -l staged_modified_desc "Staged modified file"
    contains -- modified-staged-deleted $argv; or set -ql modified_staged; and set -l modified_staged_deleted
    and set -l modified_staged_deleted_desc "Staged modified and deleted file"
    contains -- deleted $argv; and set -l deleted
    and set -l deleted_desc "Deleted file"
    contains -- deleted-staged $argv; or set -ql all_staged; and set -l deleted_staged
    and set -l staged_deleted_desc "Staged deleted file"
    contains -- ignored $argv; and set -l ignored
    and set -l ignored_desc "Ignored file"
    contains -- renamed $argv; and set -l renamed
    and set -l renamed_desc "Renamed file"
    contains -- copied $argv; and set -l copied
    and set -l copied_desc "Copied file"

    # A literal "?" for use in `case`.
    set -l q '\\?'
    if status test-feature qmark-noglob
        set q '?'
    end
    set -l use_next
    # git status --porcelain gives us all the info we need, in a format we don't.
    # The v2 format has better documentation and doesn't use " " to denote anything,
    # but it's only been added in git 2.11.0, which was released November 2016.

    # Also, we ignore submodules because they aren't useful as arguments (generally),
    # and they slow things down quite significantly.
    # E.g. `git reset $submodule` won't do anything (not even print an error).
    # --ignore-submodules=all was added in git 1.7.2, released July 2010.
    #
    set -l status_opt --ignore-submodules=all

    # If we aren't looking for ignored files, let git status skip them.
    # (don't use --ignored=no because that was only added in git 2.16, from Jan 2018.
    set -q ignored; and set -a status_opt --ignored

    # If we're looking for untracked files, we give untracked files even inside untracked directories.
    # This makes it nicer if e.g. you're in an untracked directory and want to just add one file.
    set -q untracked; and set -a status_opt -uall
    or set -a status_opt -uno

    # We need to set status.relativePaths to true because the porcelain v2 format still honors that,
    # and core.quotePath to false so characters > 0x80 (i.e. non-ASCII) aren't considered special.
    # We explicitly enable globs so we can use that to match the current token.
    set -l git_opt -c status.relativePaths -c core.quotePath=

    # We pick the v2 format if we can, because it shows relative filenames (if used without "-z").
    # We fall back on the v1 format by reading git's _version_, because trying v2 first is too slow.
    set -l ver (__fish_git --version | string replace -rf 'git version (\d+)\.(\d+)\.?.*' '$1\n$2')
    # Version >= 2.11.* has the v2 format.
    if test "$ver[1]" -gt 2 2>/dev/null; or test "$ver[1]" -eq 2 -a "$ver[2]" -ge 11 2>/dev/null
        __fish_git $git_opt status --porcelain=2 $status_opt \
            | while read -la -d ' ' line
            set -l file
            set -l desc
            # The basic status format is "XY", where X is "our" state (meaning the staging area),
            # and "Y" is "their" state.
            # A "." means it's unmodified.
            switch "$line[1..2]"
                case 'u *'
                    # Unmerged
                    # "Unmerged entries have the following format; the first character is a "u" to distinguish from ordinary changed entries."
                    # "u <xy> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>"
                    # This is first to distinguish it from normal modifications et al.
                    set -ql unmerged
                    and set file "$line[11..-1]"
                    and set desc $unmerged_desc
                case '2 .R*' '2 R.*'
                    # Renamed/Copied
                    # From the docs: "Renamed or copied entries have the following format:"
                    # "2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>"
                    # Since <sep> is \t, we can't really parse it unambiguously.
                    # The "-z" format would be great here!
                    set -ql renamed
                    and set file (string replace -r '\t[^\t]*' '' -- "$line[10..-1]")
                    and set desc $renamed_desc
                case '2 RM*' '2 RT*'
                    # Staged as renamed, with unstaged modifications (issue #6031)
                    set -ql renamed
                    or set -ql modified
                    and set file (string replace -r '\t[^\t]*' '' -- "$line[10..-1]")
                    set -ql renamed
                    and set desc $renamed_desc
                    set -ql modified
                    and set --append desc $modified_desc
                case '2 RD*'
                    # Staged as renamed, but deleted in the worktree
                    set -ql renamed
                    or set -ql deleted
                    and set file (string replace -r '\t[^\t]*' '' -- "$line[10..-1]")
                    set -ql renamed
                    and set desc $renamed_desc
                    set -ql deleted
                    and set --append desc $deleted_desc
                case '2 .C*' '2 C.*'
                    set -ql copied
                    and set file (string replace -r '\t[^\t].*' '' -- "$line[10..-1]")
                    and set desc $copied_desc
                case '1 A.*'
                    # Additions are only shown here if they are staged.
                    # Otherwise it's an untracked file.
                    set -ql added
                    and set file "$line[9..-1]"
                    and set desc $added_desc
                case '1 AD*'
                    # Added files that were since deleted
                    if set -ql added
                        set file "$line[9..-1]"
                        set desc $added_desc
                    else if set -ql deleted
                        set file "$line[9..-1]"
                        set desc $deleted_desc
                    end
                case "1 AM*" "1 AT*"
                    # Added files with additional modifications
                    # ("T" is type-changed. As of git 2.33 this appears to be undocumented.
                    # it happens when e.g. a file is replaced with a symlink.
                    # For our purposes it's the same as modified)
                    if set -ql added
                        set file "$line[9..-1]"
                        set desc $added_desc
                    else if set -ql modified
                        set file "$line[9..-1]"
                        set desc $modified_desc
                    end
                case '1 .A*'
                    # Files added with git add --intent-to-add.
                    set -ql untracked
                    and set file "$line[9..-1]"
                    and set desc $untracked_desc
                case '1 .M*' '1 .T*'
                    # Modified
                    # From the docs: "Ordinary changed entries have the following format:"
                    # "1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>"
                    # Since <path> can contain spaces, print from element 9 onwards
                    set -ql modified
                    and set file "$line[9..-1]"
                    and set desc $modified_desc
                case '1 MD*' '1 TD*'
                    set -ql modified_staged_deleted
                    and set file "$line[9..-1]"
                    and set desc $modified_staged_deleted_desc
                case '1 M.*' '1 T.*'
                    # If the character is first ("M."), then that means it's "our" change,
                    # which means it is staged.
                    # This is useless for many commands - e.g. `checkout` won't do anything with this.
                    # So it needs to be requested explicitly.
                    set -ql modified_staged
                    and set file "$line[9..-1]"
                    and set desc $staged_modified_desc
                case '1 MM*' '1 MT*' '1 TM*' '1 TT*'
                    # Staged-modified with unstaged modifications
                    # These need to be offered for both kinds of modified.
                    if set -ql modified
                        set file "$line[9..-1]"
                        set desc $modified_desc
                    else if set -ql modified_staged
                        set file "$line[9..-1]"
                        set desc $staged_modified_desc
                    end
                case '1 .D*'
                    set -ql deleted
                    and set file "$line[9..-1]"
                    and set desc $deleted_desc
                case '1 D.*'
                    # TODO: The docs are unclear on this.
                    # There is both X unmodified and Y either M or D ("not updated")
                    # and Y is D and X is unmodified or [MARC] ("deleted in work tree").
                    # For our purposes, we assume this is a staged deletion.
                    set -ql deleted_staged
                    and set file "$line[9..-1]"
                    and set desc $staged_deleted_desc
                case "$q"' *'
                    # Untracked
                    # "? <path>" - print from element 2 on.
                    set -ql untracked
                    and set file "$line[2..-1]"
                    and set desc $untracked_desc
                case '! *'
                    # Ignored
                    # "! <path>" - print from element 2 on.
                    set -ql ignored
                    and set file "$line[2..-1]"
                    and set desc $ignored_desc
            end
            # Only try printing if the file was selected.
            if set -q file[1]
                for d in $desc
                    # Without "-z", git sometimes _quotes_ filenames.
                    # It adds quotes around it _and_ escapes the character.
                    # e.g. `"a\\b"`.
                    # We just remove the quotes and hope it works out.
                    # If this contains newlines or tabs,
                    # there is nothing we can do, but that's a general issue with scripted completions.
                    set file (string trim -c \" -- $file)
                    # The relative filename.
                    if string match -q './*' -- (commandline -ct)
                        printf './%s\t%s\n' $file $d
                    else
                        printf '%s\t%s\n' "$file" $d
                    end
                    # Now from repo root.
                    # Only do this if the filename isn't a simple child,
                    # or the current token starts with ":"
                    if string match -q '../*' -- $file
                        or string match -q ':*' -- (commandline -ct)
                        set -l fromroot (builtin realpath -- $file 2>/dev/null)
                        # `:` starts pathspec "magic", and the second `:` terminates it.
                        # `/` is the magic letter for "from repo root".
                        # If we didn't terminate it we'd have to escape any special chars
                        # (non-alphanumeric, glob or regex special characters, in whatever dialect git uses)
                        and set fromroot (string replace -- "$root/" ":/:" "$fromroot")
                        and printf '%s\t%s\n' "$fromroot" $d
                    end
                end
            end
        end
    else
        # v1 format logic
        # We need to compute relative paths on our own, which is slow.
        # Pre-remove the root at least, so we have fewer components to deal with.
        set -l _pwd_list (string replace "$root/" "" -- $PWD/ | string split /)
        test -z "$_pwd_list[-1]"; and set -e _pwd_list[-1]
        # Cache the previous relative path because these are sorted, so we can reuse it
        # often for files in the same directory.
        set -l previous
        # Note that we can't use space as a delimiter between status and filename, because
        # the status can contain spaces - " M" is different from "M ".
        __fish_git $git_opt status --porcelain -z $status_opt \
            | while read -lz -d' ' line
            set -l desc
            # The entire line is the "from" from a rename.
            if set -q use_next[1]
                if contains -- $use_next $argv
                    set -l var "$use_next"_desc
                    set desc $$var
                    set -e use_next[1]
                else
                    set -e use_next[1]
                    continue
                end
            end

            # The format is two characters for status, then a space and then
            # up to a NUL for the filename.
            #
            set -l stat (string sub -l 2 -- $line)
            # The basic status format is "XY", where X is "our" state (meaning the staging area),
            # and "Y" is "their" state (meaning the work tree).
            # A " " means it's unmodified.
            #
            # Be careful about the ordering here!
            switch "$stat"
                case DD AU UD UA DU AA UU
                    # Unmerged
                    set -ql unmerged
                    and set desc $unmerged_desc
                case 'R ' RM RD
                    # Renamed/Copied
                    # These have the "from" name as the next batch.
                    # TODO: Do we care about the new name?
                    set use_next renamed
                    continue
                case 'C ' CM CD
                    set use_next copied
                    continue
                case AM
                    if set -ql added
                        set file "$line[9..-1]"
                        set desc $added_desc
                    else if set -ql modified
                        set file "$line[9..-1]"
                        set desc $modified_desc
                    end
                case AD
                    if set -ql added
                        set file "$line[9..-1]"
                        set desc $added_desc
                    else if set -ql deleted
                        set file "$line[9..-1]"
                        set desc $deleted_desc
                    end
                case 'A '
                    # Additions are only shown here if they are staged.
                    # Otherwise it's an untracked file.
                    set -ql added
                    and set desc $added_desc
                case '*M'
                    # Modified
                    set -ql modified
                    and set desc $modified_desc
                case 'M*'
                    # If the character is first ("M "), then that means it's "our" change,
                    # which means it is staged.
                    # This is useless for many commands - e.g. `checkout` won't do anything with this.
                    # So it needs to be requested explicitly.
                    set -ql modified_staged
                    and set desc $staged_modified_desc
                case '*D'
                    set -ql deleted
                    and set desc $deleted_desc
                case 'D*'
                    # TODO: The docs are unclear on this.
                    # There is both X unmodified and Y either M or D ("not updated")
                    # and Y is D and X is unmodified or [MARC] ("deleted in work tree").
                    # For our purposes, we assume this is a staged deletion.
                    set -ql deleted_staged
                    and set desc $staged_deleted_desc
                case "$q$q"
                    # Untracked
                    set -ql untracked
                    and set desc $untracked_desc
                case '!!'
                    # Ignored
                    set -ql ignored
                    and set desc $ignored_desc
            end
            if set -q desc[1]
                # Again: "XY filename", so the filename starts on character 4.
                set -l relfile (string sub -s 4 -- $line)

                set -l file
                # Computing relative path by hand.
                set -l abs (string split / -- $relfile)
                # If it's in the same directory, we just need to change the filename.
                if test "$abs[1..-2]" = "$previous[1..-2]"
                    # If we didn't have a previous file, and the current file is in the current directory,
                    # this would error out.
                    #
                    # See #5728.
                    set -q previous[1]
                    and set previous[-1] $abs[-1]
                    or set previous $abs
                else
                    set -l pwd_list $_pwd_list
                    # Remove common prefix
                    while test "$pwd_list[1]" = "$abs[1]"
                        set -e pwd_list[1]
                        set -e abs[1]
                    end
                    # Go a dir up for every entry left in pwd_list, then into $abs
                    set previous (string replace -r '.*' '..' -- $pwd_list) $abs
                end
                set -a file (string join / -- $previous)

                # The filename with ":/:" prepended.
                if string match -q '../*' -- $file
                    or string match -q ':*' -- (commandline -ct)
                    set file (string replace -- "$root/" ":/:" "$root/$relfile")
                end

                if test "$root/$relfile" -ef "$relfile"
                    and not string match -q ':*' -- (commandline -ct)
                    set file $relfile
                end

                printf '%s\n' $file\t$desc
            end
        end
    end
end
